require 'psych'
require 'stringio'

module SamBuildFast
  class TemplateParser
    attr_reader :root

    def initialize(input)
      @root = TagTranslator.new.visit(Psych.parse(input))
    end
  end

  class TreeVisitor
    def visit(node)
      case node
      when Psych::Nodes::Alias
        visit_alias(node)
      when Psych::Nodes::Document
        visit_document(node)
      when Psych::Nodes::Mapping
        visit_mapping(node)
      when Psych::Nodes::Scalar
        visit_scalar(node)
      when Psych::Nodes::Sequence
        visit_sequence(node)
      when Psych::Nodes::Stream
        visit_stream(node)
      else
        fail "Node of unexpected type #{node.class}"
      end
    end

    private

    def nonterminal(node)
      node.children.map!(&method(:visit))
      node
    end
    alias visit_document nonterminal
    alias visit_mapping nonterminal
    alias visit_sequence nonterminal
    alias visit_stream nonterminal

    def terminal(node)
      node
    end
    alias visit_scalar terminal
    alias visit_alias terminal
  end

  class TagTranslator < TreeVisitor
    private

    BUILTIN_TAG = /\A!(?:!|tag:)/

    def visit_scalar(node)
      if !node.tag || node.tag.match(BUILTIN_TAG)
        return super
      end

      process_tag(node)
    end

    def visit_sequence(node)
      if !node.tag || node.tag.match(BUILTIN_TAG)
        return super
      end

      process_tag(node)
    end

    def process_tag(node)
      case tag_name = node.tag[1..]
      when 'Ref'
        Psych::Nodes::Mapping.new.tap do |map|
          node.tag = nil
          node.plain = true if node.scalar?

          map.children << Psych::Nodes::Scalar.new(tag_name)
          map.children << node
        end
      else
        # Translate "!GetAtt a.b" => {Fn::GetAtt: [a, b]}
        if tag_name == 'GetAtt' && node.scalar?
          node = Psych::Nodes::Sequence.new.tap do |seq|
            res, att = node.value.split(?., 2)

            seq.children << Psych::Nodes::Scalar.new(res)
            seq.children << Psych::Nodes::Scalar.new(att)
          end
        end

        Psych::Nodes::Mapping.new.tap do |map|
          node.tag = nil
          node.plain = true if node.scalar?

          map.children << Psych::Nodes::Scalar.new("Fn::#{tag_name}")
          map.children << node
        end
      end
    end
  end

end
