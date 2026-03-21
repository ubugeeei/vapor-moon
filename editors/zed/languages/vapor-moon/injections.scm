; inherits: html_tags

((style_element
  (raw_text) @injection.content)
  (#set! injection.language "css"))

((script_element
  (raw_text) @injection.content)
  (#set! injection.language "moonbit"))

((interpolation
  (raw_text) @injection.content)
  (#set! injection.language "moonbit"))

(directive_attribute
  (quoted_attribute_value
    (attribute_value) @injection.content
    (#set! injection.language "moonbit")))
