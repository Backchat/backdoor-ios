#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "cp -fpR ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      cp -fpR "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "Facebook-iOS-SDK/src/FacebookSDKResources.bundle"
install_resource "Facebook-iOS-SDK/src/FBUserSettingsViewResources.bundle"
install_resource "HockeySDK/Resources/HockeySDKResources.bundle"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming-green.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming-green@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming-selected.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming-selected@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-incoming@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing-green.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing-green@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing-selected.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing-selected@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-default-outgoing@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-incoming-selected.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-incoming-selected@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-incoming.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-incoming@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-outgoing-selected.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-outgoing-selected@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-outgoing.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-square-outgoing@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-typing.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/bubble-typing@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/input-bar.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/input-bar@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/input-field.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/input-field@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/send-highlighted.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/send-highlighted@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/send.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Images/send@2x.png"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Sounds/messageReceived.aiff"
install_resource "../../../MessagesTableViewController/JSMessagesTableViewController/Resources/Sounds/messageSent.aiff"
install_resource "NoticeView/NoticeView/WBNoticeView/NoticeView.bundle"
install_resource "SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
install_resource "google-plus-ios-sdk/google-plus-ios-sdk-1.3.0/GooglePlus.bundle"
install_resource "iRate/iRate/iRate.bundle"

rsync -avr --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rm -f "$RESOURCES_TO_COPY"
