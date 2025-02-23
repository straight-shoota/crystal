require 'asciidoctor/extensions'

Asciidoctor::Extensions.register do
  inline_macro :man do
    process do |parent, target, attrs|
      section = attrs[1]
      man_ref = "#{target}(#{section})"
      if parent.document.basebackend? 'html'
        link = %(<a href="man:#{target}(#{section})">#{man_ref}</a>)
      else
        link = man_ref
      end
      create_inline parent, :quoted, link, type: :strong
    end
  end
end
