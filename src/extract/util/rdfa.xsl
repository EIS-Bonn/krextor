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
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    version="2.0">
    <xd:doc type="stylesheet">
	<xd:short>A collection of templates and utility functions for generic <a href="http://www.w3.org/TR/rdfa-primer/">RDFa</a> support, independently of the host language</xd:short>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <xd:doc type="string">Returns the default namespace URI for a CURIE of the form <code>:localname</code>.  As this is up to the host language, this is an empty implementation and intended to be overridden by the importing template.
	<xd:param name="focus" type="node">the focus node, for the namespace context</xd:param>
    </xd:doc>
    <function name="krextor:default-curie-namespace">
	<param name="focus"/>
    </function>

    <xd:doc type="string">Returns the namespace URI that is bound to the empty prefix.
	<xd:param name="focus" type="node">the focus node, for the namespace context</xd:param>
    </xd:doc>
    <function name="krextor:default-namespace">
	<param name="focus"/>
	<value-of select="namespace-uri-from-QName(resolve-QName('dummy', $focus))"/>
    </function>

    <xd:doc type="string">Converts a CURIE to a URI, using the current namespace context.
	<xd:param name="focus" type="node">the focus node, for the namespace context</xd:param>
	<xd:param name="curie" type="string">the CURIE</xd:param>
    </xd:doc>
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
				<variable name="resolved-uri" select="resolve-QName(
				    if ($prefix eq '') then $localname
				    else $curie,
				    $focus)"/>
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

    <xd:doc type="string*">Converts a sequence of CURIEs to a sequence of URIs, using the current namespace context.
	<xd:param name="focus" type="node">the focus node, for the namespace context</xd:param>
	<xd:param name="curies" type="string*">the CURIEs</xd:param>
    </xd:doc>
    <function name="krextor:curies-to-uris">
	<param name="focus"/>
	<param name="curies"/>
	<choose>
	    <when test="matches($curies, ' ')">
		<sequence select="for $c in tokenize($curies, '\s+')
		    return krextor:curie-to-uri($focus, $c)"/>
	    </when>
	    <otherwise>
		<sequence select="krextor:curie-to-uri($focus, $curies)"/>
	    </otherwise>
	</choose>
    </function>

    <xd:doc type="string">Converts a safe CURIE to a URI, using the current namespace context if the safe CURIE actually is a CURIE.
	<xd:param name="focus" type="node">the focus node, for the namespace context</xd:param>
	<xd:param name="safe-curie" type="string*">the safe CURIE</xd:param>
    </xd:doc>
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
