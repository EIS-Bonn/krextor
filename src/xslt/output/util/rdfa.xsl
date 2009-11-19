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

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <import href="../../generic/generic.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Output module for RDFa in XHTML</xd:short>
	<xd:detail>This stylesheet contains utility functions for generating RDFa output.  It is intended to be imported into an XSLT that generates XHTML, usually from the same source where the RDF is extracted from.
	    <ul>
		<li><a href="http://www.w3.org/TR/2008/REC-rdfa-syntax-20081014">Specification of XHTML+RDFa</a></li>
	    </ul>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2009</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <xd:doc>Adds RDFa attributes to the current element in the output tree,
	depending on the RDF extracted from the current node in the input
	tree.</xd:doc>
    <template name="krextor:rdfa">
	<variable name="uri" select="krextor:generate-uri(., base-uri())"/>
	<attribute name="about" select="$uri"/>
    </template>

    <xd:doc>Adds RDFa attributes to the current element in the output tree,
	depending on the RDF extracted from the current node in the input
	tree.</xd:doc>
    <template match="node()" mode="krextor:rdfa">
	<call-template name="krextor:rdfa"/>
    </template>
</stylesheet>
