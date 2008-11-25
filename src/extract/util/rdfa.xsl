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

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    version="2.0">
    <xd:doc type="stylesheet">
	<xs:short>A collection of templates and utility functions for generic <a href="http://www.w3.org/TR/rdfa-primer/">RDFa</a> support, independently of the host language</xs:short>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <function name="krextor:default-curie-namespace"/>

    <function name="krextor:curie-to-uri">
	<param name="focus"/>
	<param name="curie"/>
	<choose>
	    <when test="$curie">
		<analyze-string select="$curie" regex="^(([^:]*):)?(.+)$">
		    <matching-substring>
			<variable name="no-prefix" select="not(matches(regex-group(1), ':$'))"/>
			<variable name="prefix" select="regex-group(2)"/>
			<variable name="localname" select="regex-group(3)"/>
			<variable name="resolved-uri" select="resolve-QName($curie, $focus)"/>
			<choose>
			    <!-- the "no prefix" case is special and may not be
			         supported by every host language -->
			    <when test="$no-prefix">
				<variable name="curie">
				    <krextor:curie>
					<!-- note that $localname is the same as $curie -->
					<value-of select="$localname"/>
				    </krextor:curie>
				</variable>
				<apply-templates mode="krextor:resolve-prefixless-curie" select="$curie"/>
			    </when>
			    <otherwise>
				<!-- the "empty prefix" case is special and may not be
				     supported by every host language -->
				<variable name="namespace-uri" select="
				    if ($prefix eq '')
				    then krextor:default-curie-namespace($focus)
				    else namespace-uri-from-QName($resolved-uri)"/>
				    
				<sequence select="if ($namespace-uri)
				    then concat($namespace-uri,
					local-name-from-QName($resolved-uri))
				    else ()"/>
			    </otherwise>
			</choose>
		    </matching-substring>
		</analyze-string>
	    </when>
	    <otherwise>
		<sequence select="()"/>
	    </otherwise>
	</choose>
    </function>

    <function name="krextor:curies-to-uris">
	<param name="focus"/>
	<param name="curie"/>
	<choose>
	    <when test="matches($curie, ' ')">
		<sequence select="for $c in tokenize($curie, '\s+')
		    return krextor:curie-to-uri($focus, $c)"/>
	    </when>
	    <otherwise>
		<sequence select="krextor:curie-to-uri($focus, $curie)"/>
	    </otherwise>
	</choose>
    </function>

    <function name="krextor:safe-curie-to-uri">
	<param name="focus"/>
	<param name="safe-curie"/>
	<analyze-string select="$safe-curie" regex="^\[([^\]]+)\]$">
	    <matching-substring>
		<value-of select="krextor:curie-to-uri($focus, regex-group(1))"/>
	    </matching-substring>
	    <non-matching-substring>
		<value-of select="."/>
	    </non-matching-substring>
	</analyze-string>
    </function>
</stylesheet>
