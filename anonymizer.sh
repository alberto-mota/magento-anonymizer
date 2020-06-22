#!/bin/bash
echo "*** This script is anonymizing a DB-dump ***"

PATH_TO_ROOT=$1
if [[ "$PATH_TO_ROOT" == "" && -f "app/etc/env.php" ]]; then
  PATH_TO_ROOT="."
fi
if [[ "$PATH_TO_ROOT" == "" ]]; then
  echo "Please specify the path to your Magento store"
  exit 1
fi
CONFIG=$PATH_TO_ROOT"/.anonymizer.cfg"

if [[ 1 < $# ]]; then
  if [[ "-c" == "$1" ]]; then
    PATH_TO_ROOT=$3
    CONFIG=$2
    if [[ ! -f $CONFIG ]]; then
      echo -e "\E[1;31mCaution: \E[0mConfiguration file $CONFIG does not exist, yet! You will be asked to create it after the anonymization run."
      echo "Do you want to continue (Y/n)?"; read CONTINUE;
      if [[ ! -z "$CONTINUE" && "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        exit;
      fi
    fi
  fi
fi


while [[ ! -f $PATH_TO_ROOT/app/etc/env.php ]]; do
  echo "$PATH_TO_ROOT is no valid Magento root folder. Please enter the correct path:"
  read PATH_TO_ROOT
done

HOST='127.0.0.1'
USER='root'
PASS=''
NAME='7mesh_2_3_1_anonymous'

if [[ -f "$CONFIG" ]]; then
  echo "Using configuration file $CONFIG"
  source "$CONFIG"
fi

if [[ -z "$DEV_IDENTIFIERS" ]]; then
  DEV_IDENTIFIERS=".*(dev|stage|staging|test|anonym).*"
fi
if [[ $NAME =~ $DEV_IDENTIFIERS ]]; then
    echo "We are on the TEST environment, everything is fine"
else
    echo ""
    echo "IT SEEMS THAT WE ARE ON THE PRODUCTION ENVIRONMENT!"
    echo ""
    echo "If you are sure, this is a test environment, please type 'test' to continue"
    read force
    if [[ "$force" != "test" ]]; then
        echo "Canceled"
        exit 2
    fi
fi

if [ "$PASS" = "" ]; then
    DBCALL="mysql -u$USER -h$HOST $NAME -e"
else
    DBCALL="mysql -u$USER -p$PASS -h$HOST $NAME -e"
fi

echo "* HOST: $HOST"
echo "* USER: $USER"
echo "* NAME: $NAME"


echo "* Step 1: Anonymize Names and eMails"

if [[ -z "$ANONYMIZE" ]]; then
  echo "  Do you want me to anonymize your database (Y/n)?"; read ANONYMIZE
fi
if [[ "$ANONYMIZE" == "y" || "$ANONYMIZE" == "Y" || -z "$ANONYMIZE" ]]; then
  ANONYMIZE="y"
  # customer address
  $DBCALL "UPDATE customer_address_entity SET firstname=CONCAT('firstname ', entity_id)"
  $DBCALL "UPDATE customer_address_entity SET lastname=CONCAT('lastname ', entity_id)"
  $DBCALL "UPDATE customer_address_entity SET telephone='123-456-7890'"

  # customer
  $DBCALL "UPDATE customer_entity SET email=CONCAT('dev_',entity_id,'@anonymous_email.com')"
  $DBCALL "UPDATE customer_entity SET firstname=CONCAT('firstname ', entity_id)"
  $DBCALL "UPDATE customer_entity SET middlename=''"
  $DBCALL "UPDATE customer_entity SET lastname=CONCAT('lastname ', entity_id)"
  $DBCALL "UPDATE customer_entity SET password_hash=MD5(CONCAT('dev_',entity_id,'@anonymous_email.com'))"

  # credit memo
  $DBCALL "UPDATE sales_creditmemo_grid SET billing_name='Demo User'"
  $DBCALL "UPDATE sales_creditmemo_grid SET customer_name='Demo User'"
  $DBCALL "UPDATE sales_creditmemo_grid SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"
  $DBCALL "UPDATE magento_sales_creditmemo_grid_archive SET billing_name='Demo User'"
  $DBCALL "UPDATE magento_sales_creditmemo_grid_archive SET customer_name='Demo User'"
  $DBCALL "UPDATE magento_sales_creditmemo_grid_archive SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"

  # invoices
  $DBCALL "UPDATE sales_invoice_grid SET billing_name='Demo User'"
  $DBCALL "UPDATE sales_invoice_grid SET customer_name='Demo User'"
  $DBCALL "UPDATE sales_invoice_grid SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"
  $DBCALL "UPDATE magento_sales_invoice_grid_archive SET billing_name='Demo User'"
  $DBCALL "UPDATE magento_sales_invoice_grid_archive SET customer_name='Demo User'"
  $DBCALL "UPDATE magento_sales_invoice_grid_archive SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"

  # shipments
  $DBCALL "UPDATE sales_shipment_grid SET billing_name='Demo User'"
  $DBCALL "UPDATE sales_shipment_grid SET shipping_name='Demo User'"
  $DBCALL "UPDATE sales_shipment_grid SET customer_name='Demo User'"
  $DBCALL "UPDATE sales_shipment_grid SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"
  $DBCALL "UPDATE magento_sales_shipment_grid_archive SET billing_name='Demo User'"
  $DBCALL "UPDATE magento_sales_shipment_grid_archive SET shipping_name='Demo User'"
  $DBCALL "UPDATE magento_sales_shipment_grid_archive SET customer_name='Demo User'"
  $DBCALL "UPDATE magento_sales_shipment_grid_archive SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com')"

  # quotes
  $DBCALL "UPDATE quote SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com'), customer_firstname='Demo', customer_lastname='User', customer_middlename='Dev', remote_ip='192.168.1.1', password_hash=NULL"
  $DBCALL "UPDATE quote_address SET firstname='Demo', lastname='User', company=NULL, telephone=CONCAT('0123-4567', address_id), street=CONCAT('Devstreet ',address_id), email=CONCAT('dev_',address_id,'@anonymous_email.com')"

  # orders
  $DBCALL "UPDATE sales_order SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com'), customer_firstname='Demo', customer_lastname='User', customer_middlename='Dev'"
  $DBCALL "UPDATE sales_order_address SET email=CONCAT('dev_',entity_id,'@anonymous_email.com'), firstname='Demo', lastname='User', company=NULL, telephone=CONCAT('0123-4567', entity_id), street=CONCAT('Devstreet ',entity_id)"
  $DBCALL "UPDATE sales_order_grid SET customer_email=CONCAT('dev_',entity_id,'@anonymous_email.com'), shipping_name='Demo D. User', billing_name='Demo D. User'"

  # # payments
  $DBCALL "UPDATE sales_order_payment SET additional_data=NULL, additional_information=NULL"

  # # newsletter
  $DBCALL "UPDATE newsletter_subscriber SET subscriber_email=CONCAT('dev_newsletter_',subscriber_id,'@anonymous_email.com')"
else
  ANONYMIZE="n"
fi

echo "Done."
