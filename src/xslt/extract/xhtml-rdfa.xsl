<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Jacobs University Bremen
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
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>

<!--
    This stylesheet extracts RDF from XHTML documents annotated with RDFa.
-->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">

    <import href="util/rdfa.xsl"/>
    <import href="util/openmath/verb.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Extraction module for <a href="http://www.w3.org/TR/rdfa-primer/">XHTML+RDFa</a>, a language that allows for embedding RDF into XHTML</xd:short>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>
    
    <strip-space elements="*"/>

    <param name="autogenerate-fragment-uris" select="()"/>

    <xd:doc>Use the base URI from the <code>base</code> element in the <code>head</code>, if present</xd:doc>
    <template match="/">
	<apply-imports>
	    <with-param name="krextor:base-uri" select="/html/head/base[1]/@href" tunnel="yes"/>
	</apply-imports>
    </template>

    <xd:doc>Translates the reserved XHTML link types (as specified in the <a href="http://www.w3.org/TR/rdfa-syntax/#relValues">Metainformation Attributes Module</a>) to URIs</xd:doc>
    <template match="krextor:curie" mode="krextor:resolve-prefixless-curie" as="xs:string">
	<sequence select="if (. = (
		'alternate',
		'appendix',
		'bookmark',
		'cite',
		'chapter',
		'contents',
		'copyright',
		'first',
		'glossary',
		'help',
		'icon',
		'index',
		'last',
		'license',
		'meta',
		'next',
		'p3pv1',
		'prev',
		'role',
		'section',
		'stylesheet',
		'subsection',
		'start',
		'top',
		'up'
	    )) then concat('http://www.w3.org/1999/xhtml/vocab#', .)
	    else ''"/>
    </template>

    <!-- FIXME restrict to those elements where @about is actually allowed -->
    <!-- TODO treat @src same as @about -->
    <template match="*[@about or @typeof]">
	<call-template name="krextor:create-resource">
	    <with-param name="subject" select="krextor:safe-curie-to-uri(., @about)"/>
	    <with-param name="blank-node" select="not(@about)"/>
	    <with-param name="type" select="krextor:curies-to-uris(., @typeof)"/>
	    <!-- FIXME actually, this is:
		@content, or ...
		@... (some other RDFa properties) -->
	    <with-param name="process-next" select="*"/>
	</call-template>
    </template>
</stylesheet>
