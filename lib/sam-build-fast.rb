module SamBuildFast
  autoload :Builder, File.join(__dir__, 'sam-build-fast/builder')
  autoload :Command, File.join(__dir__, 'sam-build-fast/command')
  autoload :TemplateParser, File.join(__dir__, 'sam-build-fast/template_parser')
  autoload :Workflow, File.join(__dir__, 'sam-build-fast/workflow')
  autoload :Workflows, File.join(__dir__, 'sam-build-fast/workflows')

  autoload :Rake, File.join(__dir__, 'sam-build-fast/rake')
end
