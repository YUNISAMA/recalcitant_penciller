# Gemfile

source "https://rubygems.org"

# 指定你想要的Ruby版本
ruby '3.1.4'

# 显式指定与Ruby 3.1.4兼容的ruby_dep版本
gem 'ruby_dep', '~> 1.5'

# 如果在Windows平台上，添加wdm gem
gem 'wdm', '>= 0.1.0' if Gem.win_platform?

# Jekyll插件
group :jekyll_plugins do
    gem 'jekyll-feed'
    gem 'jekyll-sitemap'
    gem 'jekyll-paginate'
    gem 'jekyll-seo-tag'
    gem 'jekyll-archives'
    gem 'kramdown'
    gem 'rouge'
end

