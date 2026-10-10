class ApplicationController < ActionController::Base
  # Players join from whatever phone they have, so only require import map support,
  # which Turbo and Stimulus need. Rails' :modern preset would turn away iOS < 17.2.
  allow_browser versions: { safari: 16.4, chrome: 89, firefox: 108, opera: 75, ie: false }

  MAX_REMEMBERED_TOKENS = 10

  private

  # Host and player tokens are kept per record id, so one browser can host or join
  # several quizzes. Only the most recent few are kept to bound the cookie size.
  def remember_token(kind, id, token)
    tokens = session.fetch(kind, {}).merge(id.to_s => token)
    session[kind] = tokens.to_a.last(MAX_REMEMBERED_TOKENS).to_h
  end

  def remembered_token(kind, id)
    session.fetch(kind, {})[id.to_s]
  end
end
