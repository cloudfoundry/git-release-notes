require "rinku"

class GitRange
  COMMIT_FIELD_DELIMITER = "|||"
  COMMIT_DELIMITER = "SPLITHERE"
  def initialize(git_path, url, sha1, sha2)
    @submodule = git_path
    @url = url
    @sha1 = sha1
    @sha2 = sha2
    @commits = get_commits
  end

  def get_commits
    short_log = Dir.chdir(@submodule) do
      `git log #{@sha1}..#{@sha2} --pretty="#{format}#{COMMIT_DELIMITER}"`
    end
    commit_chunks = short_log.split(COMMIT_DELIMITER)
    commits = []
    commit_chunks.each do |chunk|
      segments = chunk.split(COMMIT_FIELD_DELIMITER)
      next if segments.size < 3
      commits << {
        sha: segments[0],
        author: segments[1],
        date: segments[2],
        subject: segments[3],
        body: segments[4]
      }
    end
    commits
  end

  def format
    ["%H", "%an", "%ad", "%s", "%b"].join(COMMIT_FIELD_DELIMITER)
  end

  def submodule_anchor
    %Q{<a href="#{@url}/commits/#{@sha2}" target="_blank">#{@submodule}</a>}
  end

  def commit_anchor(sha)
    %Q{<a href="#{@url}/commit/#{sha}" target="_blank">#{sha[0..7]}</a>}
  end

  def comparison_anchor
    %Q{<a href="#{@url}/compare/#{@sha1}...#{@sha2}" target="_blank">compare</a>}
  end

  def generate_html
    html = ""
    html << "<details>"
    html << "<summary><h2>#{submodule_anchor} (#{@commits.count} change(s))</h2></summary>"
    html << "<H3>#{commit_anchor(@sha1)}..#{commit_anchor(@sha2)} (#{comparison_anchor})</H3>"
    html << %Q{<div class="no-changes">No Changes</div>} if @commits.count == 0
    @commits.each do |commit|
      html << %Q{<details class="commit">}
      html << %Q{<summary class="subject">#{commit[:subject]}</summary>}

      html << %Q{<div class="sha">#{commit_anchor(commit[:sha])}</div>}
      html << %Q{<div class="body">#{linkify(commit[:body])}</div>}
      html << %Q{<div class="author">#{commit[:author]}</div>}
      html << %Q{<div class="date">#{commit[:date]}</div>}
      html << %Q{</details>}
    end
    html << "</details>"
  end

  private
  def linkify(text)
    Rinku.auto_link(String(text), mode=:all, link_attr=nil, skip_tags=nil)
  end
end
