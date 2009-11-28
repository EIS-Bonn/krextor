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
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="krextor xd"
    version="2.0">
    <import href="../generic/generic.xsl"/>
    <import href="util/prefix.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Output module for RDF/RXR</xd:short>
	<xd:detail>This is an output module for the RDF notation RXR (Regular XML RDF).  References:
	    <ul>
		<li><a href="http://www.idealliance.org/papers/dx_xmle04/papers/03-08-03/03-08-03.html">David Beckett: Modernising Semantic Web Markup</a></li>
		<li><a href="http://ilrt.org/discovery/2004/03/rxr/">XML schemas for RXR</a></li>
	    </ul>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <xd:doc>creates one RDF triple</xd:doc>
    <template name="krextor:output-triple">
	<!-- value of the subject -->
	<param name="subject"/>
	<!-- type of the subject: either 'uri' or 'blank' -->
	<param name="subject-type"/>

	<!-- value of the predicate -->
	<param name="predicate"/>

	<!-- value of the object -->
	<param name="object"/>
	<!-- type of the object: either 'uri' or 'blank',
	     or nothing for literal objects -->
	<param name="object-type"/>
	<!-- language annotation is only supported on the object,
	     but neither on triples nor on graphs, as in RXR -->
	<param name="object-language"/>
	<!-- datatype of the (literal) object -->
	<param name="object-datatype"/>

	<rxr:triple>
	    <rxr:subject>
		<attribute name="{$subject-type}" select="$subject"/>
	    </rxr:subject>
	    <rxr:predicate uri="{$predicate}"/>
	    <rxr:object>
		<if test="$object-language">
		    <attribute name="xml:lang" select="$object-language"/>
		</if>
		<choose>
		    <when test="$object-type">
			<attribute name="{$object-type}" select="$object"/>
		    </when>
		    <otherwise>
			<!-- literal object -->
			<if test="$object-datatype">
			    <attribute name="datatype" select="$object-datatype"/>
			</if>
			<choose>
			    <when test="$object-datatype eq '&rdf;XMLLiteral'">
				<copy-of select="$object"/>
			    </when>
			    <otherwise>
				<value-of select="$object"/>
			    </otherwise>
			</choose>
		    </otherwise>
		</choose>
	    </rxr:object>
	</rxr:triple>
    </template>

    <template match="/" mode="krextor:main">
	<rxr:graph>
	    <apply-imports/>
	</rxr:graph>
    </template>
</stylesheet>
