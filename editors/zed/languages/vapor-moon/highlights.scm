; inherits: html_tags

[
  "["
  "]"
] @punctuation.bracket

[
  ":"
  "."
] @character.special

[
  (interpolation)
  "@"
] @punctuation.special

(interpolation
  (raw_text) @none)

(dynamic_directive_inner_value) @variable
(directive_name) @tag.attribute

(":"
  .
  (directive_value) @variable.member)

("."
  .
  (directive_value) @property)

("@"
  .
  (directive_value) @function.method)

("#"
  .
  (directive_value) @variable)

(directive_attribute
  (quoted_attribute_value) @punctuation.special)

(directive_attribute
  (quoted_attribute_value
    (attribute_value) @none))

(directive_modifier) @function.method

((template_element) @_template
  (#set! @_template bo.commentstring "<!-- %s -->"))
