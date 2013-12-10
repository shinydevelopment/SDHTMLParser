Pod::Spec.new do |s|
  s.name         = "HTMLToAttributedString"
  s.version      = "1.0b1"
  s.summary      = "A (very) simple, regex based HTML to NSAttributedString parser."
  s.description  = <<-DESC
    HTMLToAttributedString takes a simple HTML string and parses it into an attributed string. It uses regexes, beware.
    DESC
  s.homepage     = "https://bitbucket.org/shinydevelopment/htmlparser/overview"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "Shiny Development" => "contact@shinydevelopment.com", "Dave Verwer" => "dave.verwer@shinydevelopment.com", "Greg Spiers" => "greg.spiers@shinydevelopment.com" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://daveverwer@bitbucket.org/shinydevelopment/htmlparser.git", :tag => "1.2" }
  s.source_files = "SDScreenshotCapture"
  s.framework    = 'QuartzCore'
  s.requires_arc = true
end
