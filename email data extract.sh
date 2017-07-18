#! /bin/bash
STARTDATE=$(date -d "-7 days" +"%d%m%Y")
ENDDATE=$(date -d "-1 days" +"%d%m%Y")
OUTPUTPATH="/root/spt_quotes_gac_"$STARTDATE"_"$ENDDATE".csv"
EMAIL_SUB="GAC - RAQ Report : "$STARTDATE"_"$ENDDATE
SENDLIST="comma seprated list of emails"
CCLIST="comma seprated list of emails"
EMAIL_BODY="email body"
RUN_ON_DB="psql connectionstring would go there"

echo "STARTDATE: " $STARTDATE
echo "ENDDATE: " $ENDDATE
echo "OUTPUTPATH: " $OUTPUTPATH
echo "EMAIL_SUB: " $EMAIL_SUB
echo "SENDLIST: " $SENDLIST
echo "CCLIST: " $CCLIST
echo "EMAIL_BODY: " $EMAIL_BODY

$RUN_ON_DB <<SQL
BEGIN;
CREATE TEMP TABLE spt_quotes_gac AS
SELECT
  quote_id,
  web_site_id,
  to_char(date_submission,'dd/mm/yyyy') AS date_submission,
  name,
  email,
  phone,
  postcode,
  state,
  town,
  make,
  model,
  year,
  registration,
  tyre_size,
  tyre_selected,
  additional_info,
  othserv_rotation,
  othserv_warranty,
  othserv_alignment,
  servicing_details,
  last_service,
  opt_out_product,
  vehicle_version,
  email_address_to_sent,
  num_tyres
FROM spt_quotes
WHERE date_submission >= current_date - 7
AND   date_submission <= current_date
AND   web_site_id='1'
ORDER BY spt_quotes.date_submission;
\COPY spt_quotes_gac TO '$OUTPUTPATH' WITH DELIMITER ',' CSV HEADER QUOTE '"'
ROLLBACK;
SQL

if [ "$?" = "0" ]; then
	printf "$EMAIL_BODY" | mutt -e "my_hdr From: Managed Services <Managed.Services@dws.com.au>" -s "$EMAIL_SUB" -c "$CCLIST" -a "$OUTPUTPATH" "$SENDLIST"
  if [ "$?" = "0" ]; then
	   echo "the file "$OUTPUTPATH" was sent to "$SENDLIST
  else
	   echo "There was an error sending the email, please send $OUTPUTPATH to ."
	   exit 1
  fi
else
	echo "There was an error creating the gdt-report, please create the report manually" 1>&2
  exit 1
fi
