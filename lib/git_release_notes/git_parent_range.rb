module GitReleaseNotes
  class GitParentRange
    def initialize(sha1, sha2, git_web_url)
      @submodules = find_submodules
      @submodule_logs = []
      @sha1 = sha1
      @sha2 = sha2
      @git_web_url = git_web_url
    end

    def compare_submodules
      @submodule_logs << GitRange.new(".", @git_web_url, @sha1, @sha2)

      @submodules.each do |submodule, url|
        sub_sha1 = get_submodule_commit(@sha1, submodule)
        sub_sha2 = get_submodule_commit(@sha2, submodule)
        if sub_sha1 && sub_sha2
          @submodule_logs << GitRange.new(submodule, url, sub_sha1, sub_sha2)
        else
          puts "Skipping #{submodule} (couldn't find one of the SHAs.  This is probably a new submodule in the release.)"
        end
      end
    end

    def generate_html
      template_file = File.expand_path("../views/git_parent_range.html.erb", File.dirname(__FILE__))
      renderer = ERB.new(File.read(template_file))
      renderer.result(binding)
    end

    private

    def find_submodules
      submodules = {}
      gitmodules = File.read('.gitmodules')
      gitmodules.scan(/path = (.+)\n\s+url = (.+)\n/) do |match|
        path = match[0]
        url = match[1].chomp(".git")
        if Dir.glob("#{path}/*").length > 0
          submodules[path] = url
        end
      end
      submodules
    end

    def get_submodule_commit(tree_identifier, submodule)
      ls_tree_output = `git ls-tree #{tree_identifier} #{submodule}`
      matches = /commit (.+)\s+#{submodule}/.match(ls_tree_output)
      matches[1] if matches
    end
  end
end
