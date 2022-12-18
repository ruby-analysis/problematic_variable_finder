class Parser::Builders::Default
  # More details here https://github.com/whitequark/parser/issues/283
  def string_value(token)
    value(token)
  end
end
