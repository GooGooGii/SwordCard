"""Prevent robe hems picking up nearby hands during automatic heat weighting."""


def constrain_lower_garment(body, height, waist):
    lower = {'pelvis', 'thigh.L', 'thigh.R', 'shin.L', 'shin.R', 'foot.L', 'foot.R'}
    names = {group.index: group.name for group in body.vertex_groups}
    pelvis = body.vertex_groups.get('pelvis')
    changed = 0
    for vertex in body.data.vertices:
        if vertex.co.z > waist * height:
            continue
        # Hands and hanging sleeves can be below the waist too. Keep their arm
        # weights outside the central hip region instead of freezing them.
        if abs(vertex.co.x) > .16 * height and vertex.co.z > .36 * height:
            continue
        weights = [(names[g.group], g.weight) for g in vertex.groups if names[g.group] in lower]
        unwanted = [names[g.group] for g in vertex.groups if names[g.group] not in lower]
        if not unwanted:
            continue
        for name in unwanted:
            body.vertex_groups[name].remove([vertex.index])
        total = sum(w for _, w in weights)
        if total < 1e-6:
            pelvis.add([vertex.index], 1, 'REPLACE')
        else:
            for name, weight in weights:
                body.vertex_groups[name].add([vertex.index], weight / total, 'REPLACE')
        changed += 1
    print(f'lower garment weight corrections: {changed}')
