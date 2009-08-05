<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  KWARC, Jacobs University Bremen
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
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <import href="../generic/generic.xsl"/>
    <import href="rxr.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Output module for RDF/XML</xd:short>
	<xd:detail>This stylesheet provides low-level triple-creation functions
	    and templates for an RDF/XML extraction from XML languages.
	    <ul>
		<li><a href="http://www.w3.org/TR/2004/REC-rdf-syntax-grammar-20040210/">Specification of RDF/XML</a></li>
	    </ul>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2009</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <function name="krextor:rdf-xml-grouping-key" as="xs:string*">
	<param name="attribute"/>
	<sequence select="local-name($attribute)"/>
	<sequence select="$attribute"/>
    </function>

    <xd:doc>Split a given URI into a sequence of namespace prefix and localname; the substring up to and including the last <code>#</code> or <code>/</code> is treated as the namespace prefix.</xd:doc>
    <function name="krextor:split-prefix-localname">
	<param name="uri"/>
	<analyze-string select="$uri" regex="^(.*[/#])([^/#]*)$">
	    <matching-substring>
		<sequence select="regex-group(1), regex-group(2)"/>
	    </matching-substring>
	    <non-matching-substring>
		<sequence select="'', $uri"/>
	    </non-matching-substring>
	</analyze-string>	
    </function>

    <xd:doc>Process a single triple, but only output predicate and object.  We assume that the enclosing <code>rdf:Description</code> for the subject has already been created, for this triple and all other triples with the same subject.
	<xd:param name="namespaces" type="node">Prefix to namespace URI mappings to respect (XML data structure)</xd:param>
    </xd:doc>
    <template match="rxr:triple">
	<param name="namespaces"/>

	<variable name="split-predicate-uri" select="krextor:split-prefix-localname(rxr:predicate/@uri)"/>
	<variable name="namespace-prefix" select="$namespaces/*[@uri eq $split-predicate-uri[1]][1]/@prefix"/>
	<!-- output the predicate(s) with their objects -->
	<element name="{$namespace-prefix}:{$split-predicate-uri[2]}" namespace="{$split-predicate-uri[1]}">
	    <if test="rxr:object/@xml:lang">
		<attribute name="xml:lang" select="rxr:object/@xml:lang"/>
	    </if>
	    <if test="rxr:object/@datatype">
		<choose>
		    <when test="rxr:object/@datatype eq '&rdf;XMLLiteral'">
			<attribute name="rdf:parseType">Literal</attribute>
		    </when>
		    <otherwise>
			<attribute name="rdf:datatype" select="rxr:object/@datatype"/>
		    </otherwise>
		</choose>
	    </if>
	    <choose>
		<when test="rxr:object/@uri">
		    <attribute name="rdf:resource" select="rxr:object/@uri"/>
		</when>
		<when test="rxr:object/@blank">
		    <attribute name="rdf:nodeID" select="rxr:object/@blank"/>
		</when>
		<otherwise>
		    <copy-of select="rxr:object/node()"/>
		</otherwise>
	    </choose>
	</element>
    </template>

    <xd:doc>We obtain the RDF graph as RXR and then regroup the triples
	by subject</xd:doc>
    <template match="/">
	<variable name="rxr">
	    <apply-imports/>
	</variable>
	<!-- generate namespace prefixes for all predicate URIs -->
	<variable name="namespaces">
	    <krextor:namespace prefix="rdf" uri="&rdf;"/>
	    <for-each-group select="$rxr/rxr:graph/rxr:triple/rxr:predicate" group-by="krextor:split-prefix-localname(@uri)[1]">
		<krextor:namespace prefix="ns{position()}" uri="{current-grouping-key()}"/>
	    </for-each-group>
	</variable>

	<rdf:RDF>
	    <!-- output generated namespace prefixes -->
	    <for-each select="$namespaces/*">
		<namespace name="{@prefix}" select="@uri"/>
	    </for-each>

	    <for-each-group select="$rxr/rxr:graph/rxr:triple[rxr:subject/@blank]" group-by="rxr:subject/@blank">
		<!-- output the subject (blank node) -->
		<rdf:Description rdf:nodeID="{current-grouping-key()}">
		    <apply-templates select="current-group()">
			<with-param name="namespaces" select="$namespaces"/>
		    </apply-templates>
		</rdf:Description>
	    </for-each-group>

	    <for-each-group select="$rxr/rxr:graph/rxr:triple[rxr:subject/@uri]" group-by="rxr:subject/@uri">
		<!-- output the subject (URI node) -->
		<rdf:Description rdf:about="{current-grouping-key()}">
		    <apply-templates select="current-group()">
			<with-param name="namespaces" select="$namespaces"/>
		    </apply-templates>
		</rdf:Description>
	    </for-each-group>
	</rdf:RDF>
    </template>
</stylesheet>
