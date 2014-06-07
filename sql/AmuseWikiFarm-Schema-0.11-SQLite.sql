-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Jun  7 12:55:08 2014
-- 

BEGIN TRANSACTION;

--
-- Table: role
--
DROP TABLE role;

CREATE TABLE role (
  id INTEGER PRIMARY KEY NOT NULL,
  role varchar(128)
);

CREATE UNIQUE INDEX role_unique ON role (role);

--
-- Table: site
--
DROP TABLE site;

CREATE TABLE site (
  id varchar(8) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'blog',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question text NOT NULL DEFAULT '',
  magic_answer text NOT NULL DEFAULT '',
  fixed_category_list text,
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(32),
  mail varchar(128),
  canonical varchar(255) NOT NULL DEFAULT '',
  sitegroup varchar(32),
  bb_page_limit integer NOT NULL DEFAULT 1000,
  tex integer NOT NULL DEFAULT 1,
  pdf integer NOT NULL DEFAULT 1,
  a4_pdf integer NOT NULL DEFAULT 1,
  lt_pdf integer NOT NULL DEFAULT 1,
  html integer NOT NULL DEFAULT 1,
  bare_html integer NOT NULL DEFAULT 1,
  epub integer NOT NULL DEFAULT 1,
  zip integer NOT NULL DEFAULT 1,
  ttdir varchar(1024) NOT NULL DEFAULT '',
  papersize varchar(64) NOT NULL DEFAULT '',
  division integer NOT NULL DEFAULT 12,
  bcor varchar(16) NOT NULL DEFAULT '0mm',
  fontsize integer NOT NULL DEFAULT 10,
  mainfont varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  twoside integer NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

--
-- Table: user
--
DROP TABLE user;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(128) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX username_unique ON user (username);

--
-- Table: attachment
--
DROP TABLE attachment;

CREATE TABLE attachment (
  id INTEGER PRIMARY KEY NOT NULL,
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX attachment_idx_site_id ON attachment (site_id);

CREATE UNIQUE INDEX uri_site_id_unique ON attachment (uri, site_id);

--
-- Table: category
--
DROP TABLE category;

CREATE TABLE category (
  id INTEGER PRIMARY KEY NOT NULL,
  name text,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  sorting_pos integer NOT NULL DEFAULT 0,
  text_count integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX category_idx_site_id ON category (site_id);

CREATE UNIQUE INDEX uri_site_id_type_unique ON category (uri, site_id, type);

--
-- Table: job
--
DROP TABLE job;

CREATE TABLE job (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(8) NOT NULL,
  task varchar(32),
  payload text,
  status varchar(32),
  created datetime NOT NULL,
  completed datetime,
  priority integer,
  produced varchar(255),
  errors text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX job_idx_site_id ON job (site_id);

--
-- Table: title
--
DROP TABLE title;

CREATE TABLE title (
  id INTEGER PRIMARY KEY NOT NULL,
  title text NOT NULL DEFAULT '',
  subtitle text NOT NULL DEFAULT '',
  lang varchar(3) NOT NULL DEFAULT 'en',
  date text NOT NULL DEFAULT '',
  notes text NOT NULL DEFAULT '',
  source text NOT NULL DEFAULT '',
  list_title text NOT NULL DEFAULT '',
  author text NOT NULL DEFAULT '',
  uid varchar(255),
  attach varchar(255),
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_idx_site_id ON title (site_id);

CREATE UNIQUE INDEX uri_f_class_site_id_unique ON title (uri, f_class, site_id);

--
-- Table: vhost
--
DROP TABLE vhost;

CREATE TABLE vhost (
  name varchar(255) NOT NULL,
  site_id varchar(8) NOT NULL,
  PRIMARY KEY (name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX vhost_idx_site_id ON vhost (site_id);

--
-- Table: revision
--
DROP TABLE revision;

CREATE TABLE revision (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(8) NOT NULL,
  title_id integer NOT NULL,
  f_full_path_name text,
  message text,
  status varchar(16) NOT NULL DEFAULT 'editing',
  session_id varchar(255),
  updated datetime NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX revision_idx_site_id ON revision (site_id);

CREATE INDEX revision_idx_title_id ON revision (title_id);

--
-- Table: user_role
--
DROP TABLE user_role;

CREATE TABLE user_role (
  user_id integer NOT NULL,
  role_id integer NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_role_idx_role_id ON user_role (role_id);

CREATE INDEX user_role_idx_user_id ON user_role (user_id);

--
-- Table: user_site
--
DROP TABLE user_site;

CREATE TABLE user_site (
  user_id integer NOT NULL,
  site_id varchar(8) NOT NULL,
  PRIMARY KEY (user_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_site_idx_site_id ON user_site (site_id);

CREATE INDEX user_site_idx_user_id ON user_site (user_id);

--
-- Table: title_category
--
DROP TABLE title_category;

CREATE TABLE title_category (
  title_id integer NOT NULL,
  category_id integer NOT NULL,
  PRIMARY KEY (title_id, category_id),
  FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_category_idx_category_id ON title_category (category_id);

CREATE INDEX title_category_idx_title_id ON title_category (title_id);

COMMIT;
