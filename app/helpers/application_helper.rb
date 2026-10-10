module ApplicationHelper
  # "2.3s", or nil for answers recorded before response times were tracked
  def response_time(answer)
    "#{number_with_precision(answer.response_time_ms / 1000.0, precision: 1)}s" if answer.response_time_ms
  end

  # The QR encodes the URL as squares, never as text, so the SVG is safe to output as-is
  def qr_code_svg(url)
    RQRCode::QRCode.new(url).as_svg(module_size: 5, offset: 10, use_path: true, viewbox: true,
      color: "1b1240", fill: "ffffff").html_safe
  end
end
