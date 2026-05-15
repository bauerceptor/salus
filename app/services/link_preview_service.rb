class LinkPreviewService
  def initialize(url)
    @url = url
  end

  def call
    return nil unless valid_url?

    html = fetch_html
    return nil unless html

    extract_preview(html)
  rescue StandardError
    nil
  end

  private

  attr_reader :url

  def valid_url?
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  def fetch_html
    response = HTTParty.get(url, timeout: 5, follow_redirects: true)
    response.success? ? response.body : nil
  rescue StandardError
    nil
  end

  def extract_preview(html)
    doc = Nokogiri::HTML(html)

    title = doc.at_css("meta[property='og:title']")&.[]("content") ||
            doc.at_css("title")&.text

    description = doc.at_css("meta[property='og:description']")&.[]("content") ||
                  doc.at_css("meta[name='description']")&.[]("content")

    image = doc.at_css("meta[property='og:image']")&.[]("content")

    return nil unless title

    {
      title: title.strip,
      description: description&.strip,
      image: image&.strip
    }
  end
end
