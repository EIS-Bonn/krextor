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
    <!ENTITY nfo "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
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
    <xd:short>Extraction module for <a href="http://pyxml.sourceforge.net/topics/xbel/">XBEL</a> (as used by the Konqueror browser for its bookmarks)"</xd:short>
    <xd:author>Christoph Lange</xd:author>
    <xd:copyright>Christoph Lange, 2012</xd:copyright>
    <xd:svnId>$Id$</xd:svnId>
  </xd:doc>
  
  <!-- bookmark/@id attributes are a rare exception in XBEL; therefore, we simply generate random but unique IDs for the bookmarks. -->
  <xsl:param name="autogenerate-fragment-uris" select="'generate-id'"/>
  
  <xd:doc>maps XML elements to types (a.k.a. classes) of RDF resources</xd:doc>
  <xsl:variable name="krextor:resources">
    <!-- We declare explicit types for bookmarks, even though the NFO says
         nfo:bookmarks rdfs:domain nfo:Bookmark
         but Nepomuk does not seem to apply this reliably when importing RDF. -->
    <bookmark type="&nfo;Bookmark"/>
  </xsl:variable>

  <xd:doc>activates mapping to RDF types as declared above for some elements</xd:doc>
  <xsl:template match="bookmark" mode="krextor:main">
    <xsl:apply-templates select="." mode="krextor:create-resource"/>
  </xsl:template>
  
  <xd:doc>
    <xd:short>maps XML elements and attributes to literal-valued RDF properties</xd:short>
    <xd:detail>maps XML elements and attributes to literal-valued RDF properties.  Attribute mappings are distinguished from element mappings by an additional attribute <code>krextor:attribute="yes"</code>.</xd:detail>
  </xd:doc>
  <xsl:variable name="krextor:literal-properties">
    <title property="&dcterms;title"/>
    <added property="&dcterms;created" datatype="&xsd;dateTime" krextor:attribute="yes"/>
    <modified property="&dcterms;modified &nuao;lastModification" datatype="&xsd;dateTime" krextor:attribute="yes"/>
    <visited property="&nuao;lastUsage" datatype="&xsd;dateTime" krextor:attribute="yes"/>
  </xsl:variable>

  <xd:doc>activates mapping to literal properties as declared above for some elements/attributes</xd:doc>
  <xsl:template match="bookmark/title
                       |bookmark/@added
                       |bookmark/@modified
                       |bookmark/@visited" mode="krextor:main">
    <xsl:apply-templates select="." mode="krextor:add-literal-property"/>
  </xsl:template>
  
  <xd:doc>maps XML attributes to URI-valued RDF properties</xd:doc>
  <xsl:variable name="krextor:uri-properties">
    <href property="&nfo;bookmarks" iri="true" krextor:attribute="yes"/>
  </xsl:variable>

  <xd:doc>activates mapping to URI-valued properties as declared above for some attributes</xd:doc>
  <xsl:template match="bookmark/@href" mode="krextor:main">
    <xsl:apply-templates select="." mode="krextor:add-uri-property"/>
  </xsl:template>
  
  <xsl:variable name="EPOCH" as="xs:dateTime" select="xs:dateTime('1970-01-01T00:00:00')"/>
  
  <xd:doc>converts a count of seconds since the epoch (see the <code>EPOCH</code> constant above) to an <code>xs:dateTime</code> value</xd:doc>
  <xsl:function name="krextor:epoch-to-dateTime" as="xs:dateTime">
    <xsl:param name="timestamp" as="xs:integer"/><!-- actually xs:nonNegativeInteger, but Saxon HE doesn't support that -->
    <xsl:variable name="secondDuration" select="xs:dayTimeDuration(concat('PT', $timestamp, 'S'))"/>
    <xsl:value-of select="$secondDuration + $EPOCH"/>
  </xsl:function>
  
  <xd:doc>enables metadata processing only for KDE and FreeDesktop metadata; we don't care about the rest</xd:doc>
  <xsl:template match="info" mode="krextor:main">
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

  <xsl:template match="metadata[@owner='http://freedesktop.org']/bookmark:applications[bookmark:application/@count]" mode="krextor:main">
    <xsl:call-template name="krextor:add-literal-property">
      <xsl:with-param name="property" select="'&nuao;usageCount'"/>
      <xsl:with-param name="object" select="sum(bookmark:application/@count)"/>
      <xsl:with-param name="datatype" select="'&xsd;nonNegativeInteger'"/>
    </xsl:call-template>
  </xsl:template>
</xsl:stylesheet>
