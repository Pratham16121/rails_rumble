module AvatarHelper
  AVATAR_COLORS = %w[ #ff5fa2 #ffd23f #2ee6a6 #5ea2ff #a993ff #ff8a3d #4dd8e8 #f25c54 ].freeze

  # A little doodle monster built from the nickname, so a player looks the same on every
  # screen. Zlib.crc32 rather than String#hash, which Ruby randomizes per process.
  def avatar_for(participant, size: 40)
    seed = Zlib.crc32(participant.nickname.downcase)
    color = AVATAR_COLORS[seed % AVATAR_COLORS.size]
    parts = [ seed / 8 % 3, seed / 24 % 3, seed / 72 % 3, seed / 216 % 3 ]

    tag.svg(class: "avatar", width: size, height: size, viewBox: "0 0 48 48", aria: { hidden: true }) do
      body, eyes, mouth, extra = parts
      safe_join([ avatar_extra(extra), avatar_body(body, color), avatar_eyes(eyes), avatar_mouth(mouth) ])
    end
  end

  private

  def avatar_body(variant, color)
    case variant
    when 0 then tag.circle(cx: 24, cy: 26, r: 17, fill: color, class: "outline")
    when 1 then tag.rect(x: 7, y: 10, width: 34, height: 33, rx: 11, fill: color, class: "outline")
    else tag.path(d: "M8 27a16 16 0 0 1 32 0v14l-5.3-4-5.4 4-5.3-4-5.3 4-5.4-4L8 41z", fill: color, class: "outline")
    end
  end

  def avatar_eyes(variant)
    case variant
    when 0
      safe_join([ tag.circle(cx: 18, cy: 24, r: 2.6, class: "ink"), tag.circle(cx: 30, cy: 24, r: 2.6, class: "ink") ])
    when 1
      safe_join([ 17, 31 ].flat_map { |x|
        [ tag.circle(cx: x, cy: 23, r: 5, class: "eye-white"), tag.circle(cx: x + 1.5, cy: 24, r: 2.2, class: "ink") ]
      })
    else
      safe_join([ tag.circle(cx: 24, cy: 23, r: 7, class: "eye-white"), tag.circle(cx: 25.5, cy: 24, r: 3.2, class: "ink") ])
    end
  end

  def avatar_mouth(variant)
    case variant
    when 0 then tag.path(d: "M18 32q6 5 12 0", class: "ink-line")
    when 1 then tag.ellipse(cx: 24, cy: 34, rx: 3, ry: 3.5, class: "ink")
    else safe_join([ tag.path(d: "M17 31h14q-7 8-14 0z", class: "ink"), tag.rect(x: 22, y: 31, width: 4, height: 2.5, class: "eye-white") ])
    end
  end

  def avatar_extra(variant)
    case variant
    when 1 then safe_join([ tag.path(d: "M24 11V4", class: "ink-line"), tag.circle(cx: 24, cy: 3.5, r: 2.5, class: "ink") ])
    when 2 then safe_join([ tag.path(d: "M11 17l1-10 7 6z", class: "ink"), tag.path(d: "M37 17l-1-10-7 6z", class: "ink") ])
    else "".html_safe
    end
  end
end
