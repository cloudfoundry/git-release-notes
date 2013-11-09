require "spec_helper"

module GitReleaseNotes
  describe GitRange do
    include Capybara::RSpecMatchers
    let(:parent_repo_folder) do
      Dir.mktmpdir
    end

    let(:child_repo_folder) do
      Dir.mktmpdir
    end

    after do
      FileUtils.rm_f(parent_repo_folder)
      FileUtils.rm_f(child_repo_folder)
    end

    let(:parent_repo) { Git.init(parent_repo_folder) }

    let(:child_repo) { Git.init(child_repo_folder) }

    let(:repo_web_url) { "http://examle.com/repo1" }

    before do
      # creates a repo in a tmp folder
      child_repo = Git.init(child_repo_folder)
      child_repo.config('user.name', 'spec')
      child_repo.config('user.email', 'spec@example.com')
      `touch #{child_repo_folder}/a`
      expect($?).to eq(0)

      ## mk a commit in the submodule
      child_repo.add_all
      child_repo.commit("message")
      expect(child_repo.log.split("\n")).to have(1).item

      parent_repo.add_submodule(child_repo_folder)
      parent_repo.commit("Added submodule")
      expect(parent_repo.log.split("\n")).to have(1).item
    end

    it "generate a html file" do
      `touch #{child_repo_folder}/b`
      child_repo.add_all
      child_repo.commit("Added b")
      expect(child_repo.log.split("\n")).to have(2).item

      # bump the submodule in parent repo
      parent_repo.bump_submodule(File.basename(child_repo_folder))
      parent_repo.add_all
      parent_repo.commit("Bumped submodule")
      expect(parent_repo.log.split("\n")).to have(2).items
      commits = parent_repo.commits

      git_parent_range = nil
      Dir.chdir(parent_repo_folder) do
        git_parent_range = GitParentRange.new(commits[-1], commits[0], repo_web_url)
      end
      output = Capybara.string(git_parent_range.generate_html)

      expect(output).to have_selector("body")
      expect(output.all("body > details")).to have(2).items
      expect(output.first("body > details").first("a")["href"]).to match(/^#{repo_web_url}/)
    end


    context "with another commit in the parent dir" do
      let(:commits) { parent_repo.commits }
      before do
        `touch #{parent_repo_folder}/parent_file`
        expect($?).to eq(0)
        parent_repo.add_all
        parent_repo.commit("added parent_file")

      end

      it "suppresses submodules without changes" do
        git_parent_range = nil
        Dir.chdir(parent_repo_folder) do
          git_parent_range = GitParentRange.new(commits[-1], commits[0], repo_web_url, false)
        end

        output = Capybara.string(git_parent_range.generate_html)
        expect(output.all("body > details")).to have(1).items
      end

      it "includes submodules without changes" do
        git_parent_range = nil
        Dir.chdir(parent_repo_folder) do
          git_parent_range = GitParentRange.new(commits[-1], commits[0], repo_web_url, true)
        end

        output = Capybara.string(git_parent_range.generate_html)
        expect(output.all("body > details")).to have(2).items
      end
    end
  end
end
