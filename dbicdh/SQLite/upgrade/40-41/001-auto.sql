-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_alias varchar(8);

;
ALTER TABLE custom_formats ADD COLUMN bb_coverpage_only_if_toc smallint DEFAULT 0;

;
CREATE UNIQUE INDEX site_id_format_alias_unique ON custom_formats (site_id, format_alias);

;

COMMIT;

