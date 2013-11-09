require "thor"
module GitReleaseNotes
  class CLI < Thor
    include Thor::Actions

    desc "html", "Generates a HTML release notes document"
    method_option :from, type: :string, required: true, aliases: "-f"
    method_option :to, type: :string, required: true, aliases: "-t"
    method_option :git_web_url, type: :string, required: true, aliases: "-u"
    method_option :exclude_submodules_without_changes, type: :boolean, aliases: "-e"

    def html
      whats_in_the_deploy = GitParentRange.new(options[:from],
                                               options[:to],
                                               options[:git_web_url],
                                               !options[:exclude_submodules_without_changes])
      puts whats_in_the_deploy.generate_html
    end
  end
end

