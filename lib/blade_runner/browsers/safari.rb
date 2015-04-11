class BladeRunner::Safari < BladeRunner::Browser
  def name
    "Safari"
  end

  def command
    "/Applications/Safari.app/Contents/MacOS/Safari"
  end

  def test_url
    contents = %Q(<script>window.location = "#{super}";</script>)
    path = BladeRunner.tmp_path.join("#{name}.html").to_s
    File.write(path, contents)
    path
  end
end
