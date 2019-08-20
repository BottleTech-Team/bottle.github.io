cp themes/next/_config.yml theme_config/next/_config.yml
hexo g && hexo d

git add .
git commit -m "chore: upload config"
git push


# update algolia
export HEXO_ALGOLIA_INDEXING_KEY='a6accc6480b4a9053d9905fa81d61d9c'
hexo algolia
