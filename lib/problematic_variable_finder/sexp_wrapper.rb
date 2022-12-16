class SexpWrapper
  include Parsing

  def initialize(sexp, children)
    @sexp = sexp
    @children = children
  end

  def line
    sexp.loc.line
  end

  def first_child
    sexp.children.first
  end

  def last_child
    sexp.children.last
  end

  attr_reader :sexp, :children
end
