<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">[Deprecated] - Application Load Balancer Module</h3>
  <p align="center">
    This module has been deprecated in favor of using a [modules/aws/ec2_instance](/modules/aws/ec2_instance/) module and [modules/aws/dhcp_options_set](/modules/aws/dhcp_options_set/). This new strategy allows fore more flexability with dhcp options.  
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->

## Migration

The `dhcp_options_set` module can now be utilized to create a DHCP Options Set for a VPC. This allows for the DHCP optins to be managed separately from the VPC itself, providing more flexibility and control over the DHCP options. 

Move the state of any modules utilizing `ec2_domain_controllers` to the `ec2_instance` module using a `moved` block. See the following hashicorp [refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) documentation for information on how to perform this. 
Then move the 'dhcp_options_set' to the `dhcp_options_set` module using a `moved` block. See the following hashicorp [refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) documentation for information on how to perform this.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_


<p align="right">(<a href="#readme-top">back to top</a>)</p>
