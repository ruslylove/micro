<!-- global-bottom.vue -->
<script setup>
import { computed } from 'vue'
import { useNav, useSlideContext } from '@slidev/client'

const { currentSlideNo, total, currentSlideRoute, slides, go } = useNav()
const { $slidev } = useSlideContext()

const currentLectureTitle = computed(() => {
  const currentPath = currentSlideRoute.value?.meta?.slide?.filepath
  if (!currentPath || currentPath.endsWith('slides.md')) return ''

  if (currentSlideRoute.value?.meta?.layout === 'cover') return ''

  // Find the first slide in slides.value that belongs to the same filepath and has a title defined in its frontmatter
  const matchingSlide = slides.value.find(s =>
    s.meta?.slide?.filepath === currentPath &&
    s.meta?.slide?.frontmatter?.title
  )

  if (matchingSlide?.meta?.slide?.frontmatter?.title) {
    return matchingSlide.meta.slide.frontmatter.title
  }

  // Fallback: format the filename nicely
  const filename = currentPath.split('/').pop().replace(/\.md$/, '')
  return filename
    .split(/[-_]/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
})
</script>

<template>
    <div v-if="currentLectureTitle" class="absolute bottom-0 left-0 p-2 opacity-40 flex items-center gap-2 select-none hover:opacity-80 transition-opacity duration-300">
        <carbon:notebook-reference style="height:20px" />
        <span>{{ currentLectureTitle }}</span>
    </div>
    <div class="absolute bottom-0 right-0 p-2 opacity-40 flex items-center gap-2 select-none hover:opacity-80 transition-opacity duration-300 z-10">
        <carbon:table-of-contents style="height:20px" class="cursor-pointer relative z-10" title="Table of Contents" @click="go(2)" />
        <footer>010153521 Microprocessors {{ $slidev.configs.semester }} - Page {{ currentSlideNo }} / {{ total }}</footer>
    </div>
</template>
