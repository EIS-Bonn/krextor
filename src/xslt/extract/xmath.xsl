<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2009
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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY lamapun "http://trac.kwarc.info/lamapun#">
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
]>

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://dlmf.nist.gov/LaTeXML"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
    xmlns:latexml="http://dlmf.nist.gov/LaTeXML"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    exclude-result-prefixes="#all"
    version="2.0">

    <xd:doc type="stylesheet">
	<xd:short>Extraction module for <a href="http://dlmf.nist.gov/LaTeXML">LaTeXML</a>'s XMath format, as required for <a href="http://trac.kwarc.info/lamapun">LaMaPUn</a></xd:short>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2009</xd:copyright>
	<xd:svnId>$Id: ocd.xsl 723 2009-08-05 11:15:04Z clange $</xd:svnId>
    </xd:doc>

    <xd:doc>The way we want to generate URIs for resources of interest; can be
	a list of multiple ways.  For every way that is not part of the Krextor
	core, we have to develop a <code>krextor-genuri:name</code> template
	implementing that particular URI generation.</xd:doc>
    <param name="autogenerate-fragment-uris" select="'xmath-index'"/>

    <xd:doc>The index of an XMath element among all XMath elements in the
	document.  We assume that there are no nested XMath elements, is that
	correct?
	<xd:param name="node">the node, assumed to be an XMath element</xd:param>
    </xd:doc>
    <function name="krextor:xmath-index">
	<param name="node"/>
	<value-of select="count($node/preceding::XMath)"/>
    </function>

    <xd:doc>Our own generation of fragment URIs (index of the XMath element);
	only succeeds if we are on an XMath element</xd:doc>
    <template match="krextor-genuri:xmath-index" as="xs:string?">
	<param name="node"/>
	<param name="base-uri"/>
	<!-- this could be implemented more efficiently by breaking
	XSLT 2.0 compliance and incrementing a global counter -->
	<sequence select="krextor:fragment-uri-or-null(
	    if ($node/self::XMath) then
	        concat('m', krextor:xmath-index($node))
	    else (),
	    $base-uri)"/>
    </template>

    <!-- When we see an XMath element ... -->
    <template match="XMath" mode="krextor:main">
	<!-- ... we create an RDF resource (which can easily be declared an
	instance of some class) ... -->
	<call-template name="krextor:create-resource">
	    <!-- ... say how it is related to its parent resource (here: the
	    whole document) ... -->
	    <with-param name="related-via-properties" select="'&lamapun;hasMath'" tunnel="yes"/>
	    <!-- ... and give it some additional properties ... -->
	    <with-param name="properties">
		<!-- ... here: only a numeric ID -->
		<krextor:property
		    uri="&lamapun;id"
		    datatype="&xsd;integer">
		    <!-- this is computed twice, unfortunately -->
		    <value-of select="krextor:xmath-index(.)"/>
		</krextor:property>
	    </with-param>
	</call-template>
    </template>
</stylesheet>
