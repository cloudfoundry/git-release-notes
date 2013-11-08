require "spec_helper"

describe "Running the git_release_notes script" do
  include Capybara::RSpecMatchers

  let(:bin_dir) do
    File.expand_path("../bin", File.dirname(__FILE__))
  end

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

  it "generate a html file" do
    # creates a repo in a tmp folder
    parent_repo = Git.init(parent_repo_folder)

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

    output = nil
    repo_web_url = "http://examle.com/repo1"
    Dir.chdir parent_repo_folder do
      output = Capybara.string(`#{bin_dir}/git_release_notes #{commits[-1]} #{commits[0]} #{repo_web_url}`)
    end

    expect($?).to eq(0), "Test failed. The output is \n#{output.native.inner_html}"

    expect(output).to have_selector("body")
    expect(output).to have_selector("body > details", 2)
    expect(output.first("body > details").first("a")["href"]).to match(/^#{repo_web_url}/)
  end
end

