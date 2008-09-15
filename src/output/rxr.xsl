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

<!--
This stylesheet provides low-level triple-creation functions and templates for
an RDF/RXR extraction from XML languages.

Specification of RXR:
http://www.idealliance.org/papers/dx_xmle04/papers/03-08-03/03-08-03.html
http://ilrt.org/discovery/2004/03/rxr/
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor/"
    exclude-result-prefixes="krextor"
    version="2.0">
    <xsl:import href="../generic/generic.xsl"/>

    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <!-- creates one RDF triple -->
    <xsl:template name="krextor:output-triple">
	<!-- value of the subject -->
	<xsl:param name="subject" required="yes"/>
	<!-- type of the subject: either 'uri' or 'blank' -->
	<xsl:param name="subject-type" select="'uri'"/>

	<!-- value of the predicate -->
	<xsl:param name="predicate" required="yes"/>

	<!-- value of the object -->
	<xsl:param name="object" required="yes"/>
	<!-- type of the object: either 'uri' or 'blank',
	     or nothing for literal objects -->
	<xsl:param name="object-type"/>
	<!-- language annotation is only supported on the object,
	     but neither on triples nor on graphs, as in RXR -->
	<xsl:param name="object-language"/>
	<!-- datatype of the (literal) object -->
	<xsl:param name="object-datatype"/>

	<rxr:triple>
	    <rxr:subject>
		<xsl:attribute name="{$subject-type}" select="$subject"/>
	    </rxr:subject>
	    <rxr:predicate uri="{$predicate}"/>
	    <rxr:object>
		<xsl:if test="$object-language">
		    <xsl:attribute name="xml:lang" select="$object-language"/>
		</xsl:if>
		<xsl:choose>
		    <xsl:when test="$object-type">
			<xsl:attribute name="{$object-type}" select="$object"/>
		    </xsl:when>
		    <xsl:otherwise>
			<!-- literal object -->
			<xsl:if test="$object-datatype">
			    <xsl:attribute name="datatype" select="$object-datatype"/>
			</xsl:if>
			<xsl:value-of select="$object"/>
		    </xsl:otherwise>
		</xsl:choose>
	    </rxr:object>
	</rxr:triple>
    </xsl:template>

    <xsl:template match="/">
	<rxr:graph>
	    <xsl:apply-imports/>
	</rxr:graph>
    </xsl:template>
</xsl:stylesheet>
