require "redcarpet"
require "nokogiri"

class ReMarkdown

  attr_reader :xml

  def initialize(input)
    render = Redcarpet::Render::HTML.new \
      :filter_html => true

    markdown = Redcarpet::Markdown.new render, \
      :no_intra_emphasis => true,
      :fenced_code_blocks => true,
      :superscript => true

    @xml = Nokogiri::HTML::Document.parse("<doc>#{markdown.render(input)}</doc>")

    @links = []
    @indent = 0

    @ol_depth = 0
    @ol_index = [0] * 10
  end

  def to_s
    parts = []

    @xml.at("//doc").children.each do |node|
      parts << format_block_node(node)
      parts << flush_links
    end

    parts.compact.join("\n") + "\n"
  end

  private

  def flush_links
    return if @links.empty?

    rv = @links.map do |id, href|
      "[%s]: %s\n" % [id, href]
    end.join

    @links = []

    rv
  end

  def format_block_node(node)
    case node.name.downcase
    when "h1", "h2", "h3", "h4", "h5", "h6"
      format_header(node) + "\n"
    when "p"
      format_inline_nodes(node.children) + "\n"
    when "pre"
      code = node.child
      content = code.content.chomp

      if code["class"]
        klass = code["class"]
      else
        # Test for @cli clause
        if content =~ /\A@cli\n/
          content = content.gsub(/\A@cli\n/, "")
          klass = "cli"
        end
      end

      "```#{klass}\n" + content + "\n```\n"
    when "ul"
      format_ul(node) + "\n"
    when "ol"
      format_ol(node) + "\n"
    when "text"
      # skip
    else
      raise "don't know what to do for block node #{node.name}"
    end
  end

  def inline_nodes
    ["em", "strong", "sub", "sup", "a"]
  end

  def format_inline_nodes(nodes)
    result = nodes.inject("") do |sum, node|
      text = format_inline_node(node)

      if sum.empty? || sum =~ /["(\[]$/ || text =~ /^[.,:")\]\^]/
        sum + text
      else
        sum + " " + text
      end
    end

    sentences = result.gsub(/\s*\r?\n\s*/, " ").split(/(?<=(?:[^.]\.)|[?!])\s+/)
    sentences = sentences.map do |e|
      par(e).chomp
    end

    sentences.join("\n")
  end

  def format_inline_node(node)
    if node.text?
      node.content.strip
    else
      case node.name
      when "em"
        "_" + format_inline_node(node.child) + "_"
      when "strong"
        "**" + format_inline_node(node.child) + "**"
      when "code"
        "`" + format_inline_node(node.child) + "`"
      when "sub"
        format_inline_node(node.child)
      when "sup"
        "^" + format_inline_node(node.child)
      when "a"
        href = node["href"]

        id = href.
          gsub(/[^\w]/, " ").
          split(/\s+/).
          map { |e| e.to_s[0] }.
          join.
          downcase

        @links << [id, href]

        "[%s][%s]" % [format_inline_nodes(node.children).chomp, id]
      when "img"
        src = node["src"]

        id = src.
          gsub(/[^\w]/, " ").
          split(/\s+/).
          map { |e| e.to_s[0] }.
          join.
          downcase

        @links << [id, src]

        "![%s][%s]" % [node["alt"].chomp, id]
      else
        raise "don't know what to do for inline node #{node.name}"
      end
    end
  end

  def format_header(node)
    level = node.name[/h([1-6])/, 1].to_i
    str  = "#" * level
    str += " "
    str += format_inline_nodes(node.children)
    str += "\n"
    str
  end

  def block_nodes
    ["p", "pre"]
  end

  def detect_block_in_li(nodes)
    nodes.detect do |node|
      node.name.downcase == "li" &&
        node.children.any? { |node| block_nodes.include?(node.name) }
    end
  end

  def format_li_children(nodes, has_block)
    if nodes.any? { |node| block_nodes.include?(node.name) }
      result = nodes.map do |node|
        format_block_node(node)
      end.join("\n") + "\n"
    else
      result = format_inline_nodes(nodes) + "\n"

      # Add extra newline when ul/ol contains a multi-line li
      result += "\n" if has_block

      result
    end
  end

  def format_ul(node)
    has_block = detect_block_in_li(node.children)

    children = node.children.map do |child|
      next unless child.name.downcase == "li"

      if has_block
        indent = 4
      else
        indent = 2
      end

      @indent += indent
      txt = format_li_children(child.children, has_block)
      @indent -= indent

      txt = indent(txt, indent)
      txt[0] = "*"

      txt
    end.compact

    children.map do |child|
      child
    end.join
  end

  def format_ol(node)
    @ol_depth += 1
    @ol_index[@ol_depth] = 0

    has_block = detect_block_in_li(node.children)

    children = node.children.map do |child|
      next unless child.name.downcase == "li"

      @ol_index[@ol_depth] += 1

      if has_block
        indent = 4
      else
        indent = 3
      end

      @indent += indent
      txt = format_li_children(child.children, has_block)
      @indent -= indent

      txt = indent(txt, indent)
      txt[0, 2] = "%d." % @ol_index[@ol_depth]

      txt
    end.compact

    @ol_depth -= 1

    children.map do |child|
      child
    end.join
  end

  def indent(text, level = 0)
    text.gsub(/^.*$/) do |match|
      (" " * level) + match
    end
  end

  def par(input)
    formatted = nil

    IO.popen("par p0s0w%d" % [80 - @indent], "r+") do |io|
      io.puts input
      io.close_write
      formatted = io.read
    end

    formatted
  end
end
