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

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">

    <xd:doc type="stylesheet">
	<xd:short>Utility functions and templates for Turtle-like output</xd:short>
	<xd:detail>This stylesheet provides utility functions for creating output 
	    in Turtle-like RDF serializations.
	    <ul>
		<li><a href="http://www.w3.org/TeamSubmission/turtle/">Specification of Turtle</a></li>
	    </ul>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2009</xd:copyright>
	<xd:svnId>$Id: turtle.xsl 661 2009-05-25 09:50:55Z clange $</xd:svnId>
    </xd:doc>

    <xd:doc>TODO</xd:doc>
    <function name="krextor:node-id-to-turtle" as="xs:string">
	<param name="id" as="xs:string"/>
	<param name="type" as="xs:string"/>
	<choose>
	    <when test="$type eq 'uri'">
		<value-of select="concat('&lt;', $id, '&gt;')"/>
	    </when>
	    <when test="$type eq 'blank'">
		<value-of select="concat('_:', $id)"/>
	    </when>
	    <!-- TODO verify bnode syntax -->
	    <!-- TODO fail in 'else' case -->
	    <otherwise>
		<value-of select="''"/>
	    </otherwise>
	</choose>
    </function>

    <xd:doc>TODO</xd:doc>
    <function name="krextor:literal-to-turtle" as="xs:string">
	<param name="value" as="xs:string"/>
	<param name="lang"/>
	<param name="datatype"/>
	<!-- FIXME check if """...""" is allowed in N-Triples, otherwise move to Turtle -->
	<value-of select="concat(
	    (: the value :)
	    if (contains($value, '&#xa;')) then
	        concat('&quot;&quot;&quot;', $value, '&quot;&quot;&quot;')
	    else concat('&quot;', $value, '&quot;'),
	    (: the language or datatype annotation :)
	    if ($lang) then concat('@', $lang)
	    else if ($datatype) then concat('^^&lt;', $datatype, '&gt;')
	    else '')"/>
    </function>
</stylesheet>
