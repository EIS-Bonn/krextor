<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2012
    *  Christoph Lange
    *  freeX (http://www.cul.de/freex/)
    *  http://kwarc.info/projects/krextor/
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<!DOCTYPE stylesheet [
    <!ENTITY xbel "http://example.org/xbel#">
    <!ENTITY dcterms "http://purl.org/dc/terms/">
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY nuao "http://www.semanticdesktop.org/ontologies/2010/01/25/nuao#">
    <!ENTITY nie "http://www.semanticdesktop.org/ontologies/2007/01/19/nie#">
]>

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:krextor="http://kwarc.info/projects/krextor"
  xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
  xmlns:xd="http://www.pnp-software.com/XSLTdoc"
  exclude-result-prefixes="#all"
  version="2.0">

  <xd:doc type="stylesheet">
    <xd:short>Extraction module for XBEL (as used by the Konqueror browser for its bookmarks)"</xd:short>
    <xd:author>Christoph Lange</xd:author>
    <xd:copyright>Christoph Lange, 2012</xd:copyright>
    <xd:svnId>$Id$</xd:svnId>
  </xd:doc>
  
  <xsl:param name="autogenerate-fragment-uris" select="'xbel'"/>
  
  <xsl:template match="krextor-genuri:xbel" as="xs:anyURI?">
    <xsl:param name="node"/>
    <xsl:param name="base-uri"/>
    <xsl:apply-templates select="$node" mode="krextor-genuri:xbel">
      <!-- we ignore the base URI for now; later we may pass information about the user that way -->
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="bookmark" mode="krextor-genuri:xbel" as="xs:anyURI?">
    <xsl:sequence select="xs:anyURI(iri-to-uri(@href))"/>
  </xsl:template>
  
  <xsl:variable name="krextor:resources">
    <!-- For now, we don't implement a proper XBEL vocabulary, but instead hard-code the intended axiom
         xbel:Bookmark rdfs:subClassOf nie:InformationElement -->
    <bookmark type="&xbel;Bookmark &nie;InformationElement"/>
  </xsl:variable>

  <xsl:template match="bookmark" mode="krextor:main">
    <xsl:apply-templates select="." mode="krextor:create-resource"/>
  </xsl:template>
  
  <xsl:variable name="krextor:literal-properties">
    <title property="&dcterms;title"/>
    <added property="&dcterms;created" datatype="&xsd;dateTime" krextor:attribute="yes"/>
    <modified property="&dcterms;modified &nuao;lastModification" datatype="&xsd;dateTime" krextor:attribute="yes"/>
    <visited property="&nuao;lastUsage" datatype="&xsd;dateTime" krextor:attribute="yes"/>
  </xsl:variable>

  <xsl:template match="bookmark/title
                       |bookmark/@added
                       |bookmark/@modified
                       |bookmark/@visited" mode="krextor:main">
    <xsl:apply-templates select="." mode="krextor:add-literal-property"/>
  </xsl:template>
  
  <xsl:variable name="EPOCH" as="xs:dateTime" select="xs:dateTime('1970-01-01T00:00:00')"/>
  
  <xsl:function name="krextor:epoch-to-dateTime" as="xs:dateTime">
    <xsl:param name="timestamp" as="xs:integer"/><!-- actually xs:nonNegativeInteger, but Saxon HE doesn't support that -->
    <xsl:variable name="secondDuration" select="xs:dayTimeDuration(concat('PT', $timestamp, 'S'))"/>
    <xsl:value-of select="$secondDuration + $EPOCH"/>
  </xsl:function>
  
  <xsl:template match="info" mode="krextor:main">
    <!-- We only feel responsible for KDE and FreeDesktop metadata -->
    <xsl:apply-templates select="metadata[@owner='http://www.kde.org']
                                |metadata[@owner='http://freedesktop.org']" mode="krextor:main"/>
  </xsl:template>
  
  <xsl:template match="metadata[@owner='http://www.kde.org']/time_added" mode="krextor:main">
    <xsl:call-template name="krextor:add-literal-property">
      <xsl:with-param name="property" select="'&dcterms;created'"/>
      <xsl:with-param name="object" select="krextor:epoch-to-dateTime(xs:integer(text()))"/><!-- actually xs:nonNegativeInteger, but Saxon HE doesn't support that -->
      <xsl:with-param name="datatype" select="'&xsd;dateTime'"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- 'modified' does not occur in KDE metadata -->
  
  <xsl:template match="metadata[@owner='http://www.kde.org']/time_visited" mode="krextor:main">
    <xsl:call-template name="krextor:add-literal-property">
      <xsl:with-param name="property" select="'&nuao;lastUsage'"/>
      <xsl:with-param name="object" select="krextor:epoch-to-dateTime(xs:integer(text()))"/><!-- make sure that the value is an integer number; actually xs:nonNegativeInteger, but Saxon HE doesn't support that -->
      <xsl:with-param name="datatype" select="'&xsd;dateTime'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="metadata[@owner='http://www.kde.org']/visit_count" mode="krextor:main">
    <xsl:call-template name="krextor:add-literal-property">
      <xsl:with-param name="property" select="'&nuao;usageCount'"/>
      <xsl:with-param name="object" select="xs:integer(text())"/><!-- make sure that the value is an integer number; actually xs:nonNegativeInteger, but Saxon HE doesn't support that -->
      <xsl:with-param name="datatype" select="'&xsd;nonNegativeInteger'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="metadata[@owner='http://freedesktop.org']/bookmark:applications" mode="krextor:main">
    <xsl:call-template name="krextor:add-literal-property">
      <xsl:with-param name="property" select="'&nuao;usageCount'"/>
      <xsl:with-param name="object" select="sum(bookmark:application/@count)"/>
      <xsl:with-param name="datatype" select="'&xsd;nonNegativeInteger'"/>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
