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
    <template match="*[@resource or @src or @about or @href or @typeof or @rel or @rev or @property]">
	<param name="tunneled-property" tunnel="yes"/>
	<param name="tunneled-inverse" tunnel="yes"/>

	<variable name="type" select="krextor:curies-to-uris(., @typeof)"/>
	<variable name="process-next" select="
	    (@* except 
		((if (exists(@about|@src|@typeof)) then () else (@resource|@rel|@href))|@src|@about|@typeof))
	    |(if (@property) then () else *)"/>
	<variable name="resource" select="if (exists(@about)) then @about else if (@src) then @src else if (@resource) then @resource else @href"/>
	<variable name="blank-node-id" select="if (exists($resource)) then krextor:safe-curie-to-bnode-id($resource) else ()"/>
	<variable name="related-via-properties" select="(
	    if (not(exists(@about|@src|@typeof))) then krextor:curies-to-uris(., @rel) else (),
	    if ($tunneled-property and not($tunneled-inverse)) then $tunneled-property else ())"/>
	<variable name="related-via-inverse-properties" select="(
	    if (not(exists(@about|@src|@typeof))) then krextor:curies-to-uris(., @rev) else (),
	    if ($tunneled-property and $tunneled-inverse) then $tunneled-property else ())"/>

	<choose>
	    <when test="not($tunneled-property) and @property and not(exists($resource)) and not(@rel|@rev)">
		<apply-templates select="@property"/>

	    </when>
	    <when test="$blank-node-id or not(exists($resource))">
		<call-template name="krextor:create-resource">
		    <with-param name="this-blank-node-id" select="$blank-node-id"/>
		    <with-param name="blank-node" select="true()"/>
		    <with-param name="type" select="$type"/>
		    <with-param name="related-via-properties" select="$related-via-properties"/>
		    <with-param name="related-via-inverse-properties" select="$related-via-inverse-properties"/>
		    <!-- FIXME actually, this is:
			@content, or ...
			@... (some other RDFa properties) -->
		    <with-param name="process-next" select="$process-next"/>
		</call-template>
	    </when>
	    <otherwise>
		<call-template name="krextor:create-resource">
		    <with-param name="subject" select="krextor:safe-curie-to-uri(., $resource)"/>
		    <with-param name="blank-node" select="not(exists($resource))"/>
		    <with-param name="type" select="$type"/>
		    <with-param name="related-via-properties" select="$related-via-properties"/>
		    <with-param name="related-via-inverse-properties" select="$related-via-inverse-properties"/>
		    <!-- FIXME actually, this is:
			@content, or ...
			@... (some other RDFa properties) -->
		    <with-param name="process-next" select="$process-next"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <!-- FIXME restrict to those elements where @about is actually allowed -->
    <!--
    <template match="*[not(@resource or @src or @about or @typeof or @rel or @rev)]">
	<apply-templates select="@property|@href|*"/>
    </template>
    -->
</stylesheet>
