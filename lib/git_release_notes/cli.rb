require "thor"
module GitReleaseNotes
  class CLI < Thor
    include Thor::Actions

    desc "html", "Generates an HTML release notes document showing all commits between two refs\n" +
		 "including commits within submodules"
    method_option :from,
		   desc: "SHA, tag, or other tree-ish reference for the start of the range",
		   banner: "TREEISH",
		   type: :string,
		   required: true,
		   aliases: "-f"
    method_option :to,
		   desc: "SHA, tag, or other tree-ish reference for the end of the range",
		   banner: "TREEISH",
		   type: :string,
		   required: true,
		   aliases: "-t"
    method_option :git_web_url,
		   desc: "URL of the root repository, used to create links in the generated HTML doc",
		   banner: "URL",
		   type: :string,
		   default: "https://github.com/cloudfoundry/cf-release",
		   aliases: "-u"
    method_option :exclude_submodules_without_changes,
		   desc: "Exclude showing submodules in HTML doc if there are 0 commits to it in the given range",
		   type: :boolean,
		   default: false,
		   aliases: "-e"

    def html
      puts GitParentRange.new(
	options[:from],
        options[:to],
        options[:git_web_url],
        !options[:exclude_submodules_without_changes],
      ).generate_html
    end
  end
end

