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

	firewithinstudios)
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

  refs/heads/master)
    BRANCH=master
    DIST_PATH=/var/www/site
    CONFIG_PATH=/etc/webhook/config-prod.toml
  ;;

  refs/heads/release/*)
    BRANCH="release/$(/usr/bin/basename $REF)"
    DIST_PATH=/var/www/uat
    CONFIG_PATH=/etc/webhook/config-uat.toml
  ;;

  *)
    echo "$REF was not a valid git reference"
    echo "################"
    return 1
esac

echo "checking out $BRANCH for content"
echo "################"
cd /mnt/chaos/content
/usr/bin/git fetch

# Retrieves content based on which repo is requested
#
# This approach allows me to have a release candidate for one
# repo and use master for the other, or the same release candidate
# for both.
####
case $REPO in

chaos-content)

  echo "\nfetching content"
  echo "################"
  cd /mnt/chaos/content && /usr/bin/git fetch

  echo "\nchecking out content on $BRANCH"
  echo "################"
  /usr/bin/git checkout $BRANCH

  echo "\npulling latest from $BRANCH"
  echo "################"
  /usr/bin/git pull

  echo "\nfetching theme"
  echo "################"
  cd /mnt/chaos/themes/chaos && /usr/bin/git fetch

  # if a release candidate does not exist for theme like it does for content, use master
  BRANCH_EXISTS=$(/usr/bin/git ls-remote --heads origin $REF | /usr/bin/wc -l)

  if [ $BRANCH_EXISTS == 0 ]; then

    echo "\nchecking out theme master because $BRANCH does not exist"
    echo "################"
    /usr/bin/git checkout master

    echo "\npulling latest from theme master"
    echo "################"
    /usr/bin/git pull

  else

    echo "\nchecking out theme on $BRANCH"
    echo "################"
    /usr/bin/git checkout $BRANCH

    echo "\npulling latest from $BRANCH"
    echo "################"
    /usr/bin/git pull

  fi
;;

chaos-theme)

  echo "\nfetching theme"
  echo "################"
  cd /mnt/chaos/themes/chaos && /usr/bin/git fetch

  echo "\nchecking out theme on $BRANCH"
  echo "################"
  /usr/bin/git checkout $BRANCH

  echo "\npulling latest from $BRANCH"
  echo "################"
  /usr/bin/git pull

  echo "\nfetching content"
  echo "################"
  cd /mnt/chaos/content && /usr/bin/git fetch

  # if a release candidate does not exist for theme like it does for content, use master
  BRANCH_EXISTS=$(/usr/bin/git ls-remote --heads origin $REF | /usr/bin/wc -l)

  if [ $BRANCH_EXISTS == 0 ]; then

    echo "\nchecking out content master because $BRANCH does not exist"
    echo "################"
    /usr/bin/git checkout master

    echo "\npulling latest from content master"
    echo "################"
    /usr/bin/git pull

  else

    echo "\nchecking out content on $BRANCH"
    echo "################"
    /usr/bin/git checkout $BRANCH

    echo "\npulling latest from $BRANCH"
    echo "################"
    /usr/bin/git pull

  fi
  ;;

esac

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
  --contentDir /mnt/chaos/content \
  --themesDir /mnt/chaos/themes \
  --cleanDestinationDir

if [ $BUILD_TAGS == 1 ]; then
  echo "\nremoving existing network tags"
  echo "################"
  /bin/rm -f $DIST_PATH/network/diagram.json

  echo "\nbuilding network tags"
  echo "################"
  /usr/local/bin/tagparser \
    --root /mnt/chaos/content \
    --dirs "plants/business,plants/culture,plants/entrepreneurship,plants/faith,plants/identity,plants/leadership,plants/meta,plants/parenting,plants/science,plants/technology,plants/writing" \
    --output $DIST_PATH/network/diagram.json
fi
