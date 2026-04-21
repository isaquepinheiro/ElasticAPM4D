import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Projects',
      items: [{ type: 'link', label: 'ElasticAPM4D', href: '/elasticapm4d/' }],
    },
  ],
  elasticapm4dSidebar: [
    {
      type: 'category',
      label: 'ElasticAPM4D',
      link: { type: 'doc', id: 'elasticapm4d/index' },
      items: [
        'elasticapm4d/introduction',
        {
          type: 'category',
          label: 'Getting Started',
          items: [
            'elasticapm4d/getting-started/installation',
            'elasticapm4d/getting-started/quickstart',
          ],
        },
        {
          type: 'category',
          label: 'Architecture',
          items: [
            'elasticapm4d/architecture/overview',
            'elasticapm4d/architecture/runtime-flow',
          ],
        },
        {
          type: 'category',
          label: 'Reference',
          items: ['elasticapm4d/reference/api'],
        },
        {
          type: 'category',
          label: 'Guides',
          items: ['elasticapm4d/guides/stacktrace-providers'],
        },
        {
          type: 'category',
          label: 'Tests & Support',
          items: [
            'elasticapm4d/tests/overview',
            'elasticapm4d/troubleshooting/common-errors',
          ],
        },

      ],
    },
  ],
};

export default sidebars;
