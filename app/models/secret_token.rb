# Secret tokens identify a quiz's host and each player. The raw token lives in the
# browser's session cookie; only its digest is stored in the database.
module SecretToken
  def self.generate
    SecureRandom.urlsafe_base64
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.matches?(token, digest)
    token.present? && digest.present? &&
      ActiveSupport::SecurityUtils.secure_compare(digest(token), digest)
  end
end
