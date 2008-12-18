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
This stylesheet provides low-level triple-creation functions and templates for
an RDF/RXR extraction from XML languages.

Specification of RXR:
http://www.idealliance.org/papers/dx_xmle04/papers/03-08-03/03-08-03.html
http://ilrt.org/discovery/2004/03/rxr/
-->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    exclude-result-prefixes="krextor"
    version="2.0">
    <import href="../generic/generic.xsl"/>

    <output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <!-- creates one RDF triple -->
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

    <template match="/">
	<rxr:graph>
	    <apply-imports/>
	</rxr:graph>
    </template>
</stylesheet>
