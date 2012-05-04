module ApplicationHelper
  def render_flash_messages
    s = ''
    flash.each do |k,v|
      s << content_tag('div', v, :class => "notification error png_bg")
    end
    s
  end

end
