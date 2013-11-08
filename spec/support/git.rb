class Git
  def initialize(path)
    @path = path
  end

  def self.init(path)
    FileUtils.mkdir_p(path)
    Dir.chdir path do
      `git init`
      raise "Exception running cmd" unless $? == 0
    end
    Git.new(path)
  end

  def config(key, value)
    command("config '#{key}' '#{value}'")
  end

  def add_all
    command("add --all")
  end

  def commit(message)
    command("commit -m '#{message}'")
  end

  def log(options="--oneline")
    command("log #{options}")
  end

  def commits
    log("--format='%H'").split("\n")
  end

  def add_submodule(submodule_repo)
    command("submodule add #{submodule_repo}")
  end

  def bump_submodule(submodule_name)
    Dir.chdir File.join(@path, submodule_name) do
      `git pull 2>&1`
    end
  end

  def to_path
    @path
  end

  def to_s
    File.basename(@path)
  end

  private
  def command(command)
    Dir.chdir @path do
      out = `git #{command} 2>&1`
      raise "Exception running cmd 'git #{command}', #{out}" unless $? == 0
      return out
    end
  end
end
