class NicePartials::Partial::Content
  def initialize(view_context)
    @view_context, @content = view_context, ActiveSupport::SafeBuffer.new
  end
  delegate :to_s, :present?, to: :@content

  def process(content, block)
    self unless concat(content || capture(block))
  end

  private

  def capture(block)
    @view_context.capture(&block) if block
  end

  def concat(string)
    @content << string.presence&.to_s
    string
  end
end
