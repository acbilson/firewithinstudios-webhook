#!/bin/sh
export GIT_SSH_COMMAND="/usr/bin/ssh -i /root/.ssh/git_rsa"

REF=$1
REPO=$2

CONTENT_BRANCH=unset
THEME_BRANCH=unset
PATH=unset
DIST_PATH=unset
CONFIG_PATH=unset
BUILD_TAGS=0

# Verifies that the repo is one of those authorized
####
case $REPO in

	firewithin)
    PATH=/mnt/firewithin/content
    BUILD_TAGS=1
  ;;

  *)
    echo "$REPO was not a valid git repo"
    echo "################"
    return 1
  ;;
esac

# Verifies that the branch ref is supported for webhook
####
case $REF in

  refs/heads/main)
    BRANCH=main
    DIST_PATH=/var/www/site
    CONFIG_PATH=/etc/webhook/firewithin-prod.toml
  ;;

  *)
    echo "$REF was not a valid git reference"
    echo "################"
    return 1
esac

echo "checking out $BRANCH for content"
echo "################"
cd /mnt/firewithin
/usr/bin/git fetch

# Retrieves content
####
echo "\nfetching firewithin"
echo "################"
cd /mnt/firewithin && /usr/bin/git fetch

echo "\nchecking out firewithin on $BRANCH"
echo "################"
/usr/bin/git checkout $BRANCH

echo "\npulling latest from $BRANCH"
echo "################"
/usr/bin/git pull

if [ -d /tmp/hugo_cache ]; then
  echo "\n\nclearing hugo cache from last build"
  echo "################"
  /bin/rm -rf /tmp/hugo_cache
fi

echo "\nbuilding site from $BRANCH to $DIST_PATH"
echo "################"
/usr/bin/hugo \
  -d $DIST_PATH \
  --config $CONFIG_PATH \
  --contentDir /mnt/firewithin/content \
  --themesDir /mnt/firewithin/themes \
  --cleanDestinationDir
