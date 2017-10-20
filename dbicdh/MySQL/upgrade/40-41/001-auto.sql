-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_alias varchar(8) NULL,
                           ADD COLUMN bb_coverpage_only_if_toc smallint NULL DEFAULT 0,
                           ADD UNIQUE site_id_format_alias_unique (site_id, format_alias);

;

COMMIT;

