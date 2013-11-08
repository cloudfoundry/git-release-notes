require "spec_helper"

describe GitRange do
  include Capybara::RSpecMatchers

  let(:repo_path) do
    Dir.mktmpdir
  end

  let(:repo) do
    Git.init(repo_path)
  end

  context "with the first commit" do
    before do
      repo.config("user.name", "an author")
      Dir.chdir repo_path do
        `touch a`
        repo.add_all
        repo.commit("add a")
      end
    end

    context "and a second commit" do
      before do
        Dir.chdir repo_path do
          `touch b`
          repo.add_all
          repo.commit("#{second_short_log}\n\n#{second_body}")
        end
      end

      let(:second_short_log) do
        "add b"
      end

      let(:second_body) do
        "this is a body (#{second_url})"
      end

      let(:second_url) do
        "http://example.com/a_link"
      end

      let(:author) do
        "an author"
      end

      it "can return a list of commits between two refs" do
        expect(repo.commits).to have(2).items

        earlier_ref, later_ref = repo.commits.reverse

        git_range = GitRange.new(repo, "http://example.com/repo1", earlier_ref, later_ref)
        expect(git_range.get_commits).to have(1).item
        commit = git_range.get_commits.first
        expect(commit.fetch(:sha)).to eql(later_ref)
        expect(commit.fetch(:author)).to eql(author)
        expect(commit.fetch(:date)).to be
        expect(commit.fetch(:subject)).to eql(second_short_log)
        expect(commit.fetch(:body)).to include(second_body)
      end

      it "can generate the HTML" do
        earlier_ref, later_ref = repo.commits.reverse
        git_range = GitRange.new(repo, "http://example.com/repo1", earlier_ref, later_ref)
        details = Capybara.string(git_range.generate_html)
        expect(details).to have_selector("details")
        expect(details).to have_selector("details > summary", text: repo.to_s)
        expect(details.find("details > summary", text: "1 commits"))
        expect(details.find("details > summary  a")["href"]).to eql("http://example.com/repo1/commits/#{later_ref}")
        expect(details.find("details > h3", text: "#{earlier_ref[0..7]}..#{later_ref[0..7]}"))
        expect(details.find("details > h3 > a:nth-child(1)")["href"]).to eql("http://example.com/repo1/commit/#{earlier_ref}")
        expect(details.find("details > h3 > a:nth-child(2)")["href"]).to eql("http://example.com/repo1/commit/#{later_ref}")

        expect(details.find("details > h3 > a:last-child")["href"]).to eql("http://example.com/repo1/compare/#{earlier_ref}...#{later_ref}")

        expect(details.find("details > details.commit")).to be
        expect(details.find("details > details > summary.subject", text: second_short_log)).to be
        expect(details.find("details > details > div.sha", text: later_ref[0..7])).to be
        expect(details.find("details > details > div.sha > a")["href"]).to eql("http://example.com/repo1/commit/#{later_ref}")
        expect(details.find("details > details > div.body", text: second_body)).to be
        expect(details.find("details > details > div.body > a")["href"]).to eql(second_url)
        expect(details.find("details > details > div.author", text: author)).to be
        expect(details.find("details > details > div.date")).to be
      end

      context "and a third commit" do
        before do
          Dir.chdir repo_path do
            `touch c`
            repo.add_all
            repo.commit("third commit")
          end
        end

        it "has mutilple commits in the HTML" do
          earlier_ref, later_ref = repo.commits[-1], repo.commits[0]
          details = Capybara.string(GitRange.new(repo, "http://example.com/repo1", earlier_ref, later_ref).generate_html)
          expect(details.all("details > details.commit")).to have(2).items
        end
      end
    end

    context "when the commit has no body" do
      before do
        Dir.chdir repo_path do
          `touch b`
          repo.add_all
          repo.commit("add b")
        end
      end

      it "has the nil value in the body" do
        earlier_ref, later_ref = repo.commits.reverse
        git_range = GitRange.new(repo, "http://example.com/repo1", earlier_ref, later_ref)
        commit = git_range.get_commits.first
        expect(commit.fetch(:body)).to eql(nil)
      end

      it "does not barf" do
        earlier_ref, later_ref = repo.commits.reverse
        git_range = GitRange.new(repo, "http://example.com/repo1", earlier_ref, later_ref)
        expect{git_range.generate_html}.to_not raise_error
      end
    end

    it "should show no changes" do
      only_ref = repo.commits[0]

      git_range = GitRange.new(repo, "http://example.com/repo1", only_ref, only_ref)
      details = Capybara.string(git_range.generate_html)

      expect(details.find("details > div.no-changes")).to be
    end
  end
end


