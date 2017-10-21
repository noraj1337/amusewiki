-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/42/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_2up varchar(8) NOT NULL DEFAULT '40-80';

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_4up varchar(8) NOT NULL DEFAULT '40-80';

;

COMMIT;

