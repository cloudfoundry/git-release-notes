require "thor"
module GitReleaseNotes
  class CLI < Thor
    include Thor::Actions

    desc "html", "Generates a HTML release notes document"
    method_option :from, type: :string, required: true
    method_option :to, type: :string, required: true
    method_option :git_web_url, type: :string, required: true
    method_option :include_submodule_without_changes, type: :boolean, default: true

    def html
      whats_in_the_deploy = GitParentRange.new(options[:from],
                                               options[:to],
                                               options[:git_web_url],
                                               options[:include_submodule_without_changes])
      puts whats_in_the_deploy.generate_html
    end
  end
end

